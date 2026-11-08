use crate::domain::{LogEntry, LogLevel};
use crossbeam_channel::Sender;
use std::path::PathBuf;
use std::process::Stdio;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;

#[derive(Default)]
pub struct LogcatAdapter {
    is_running: Arc<AtomicBool>,
}

impl LogcatAdapter {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn is_active(&self) -> bool {
        self.is_running.load(Ordering::SeqCst)
    }

    pub fn start(&self, adb_path: PathBuf, device_id: String, tx: Sender<LogEntry>) {
        if self.is_running.swap(true, Ordering::SeqCst) {
            return;
        }

        let flag = Arc::clone(&self.is_running);
        tokio::spawn(async move {
            let mut cmd = Command::new(&adb_path);
            cmd.args(["-s", &device_id, "logcat", "-v", "threadtime"])
                .stdout(Stdio::piped())
                .stderr(Stdio::null());

            if let Ok(mut child) = cmd.spawn() {
                if let Some(stdout) = child.stdout.take() {
                    let mut reader = BufReader::new(stdout).lines();
                    let mut id_seq: u64 = 0;

                    while flag.load(Ordering::SeqCst) {
                        match reader.next_line().await {
                            Ok(Some(line)) => {
                                if let Some(entry) = Self::parse_line(id_seq, &line) {
                                    id_seq += 1;
                                    if tx.send(entry).is_err() {
                                        break;
                                    }
                                }
                            }
                            Ok(None) => break,
                            Err(_) => break,
                        }
                    }
                }
                let _ = child.kill().await;
            }
            flag.store(false, Ordering::SeqCst);
        });
    }

    pub fn stop(&self) {
        self.is_running.store(false, Ordering::SeqCst);
    }

    pub fn parse_line(id: u64, line: &str) -> Option<LogEntry> {
        let trimmed = line.trim();
        if trimmed.starts_with("--------- beginning of") || trimmed.is_empty() {
            return None;
        }

        let mut tokens = Vec::with_capacity(5);
        let mut char_indices = trimmed.char_indices().peekable();
        let mut start = None;

        while let Some(&(idx, ch)) = char_indices.peek() {
            if ch.is_whitespace() {
                if let Some(s) = start.take() {
                    tokens.push(&trimmed[s..idx]);
                    if tokens.len() == 5 {
                        break;
                    }
                }
                char_indices.next();
            } else {
                if start.is_none() {
                    start = Some(idx);
                }
                char_indices.next();
            }
        }

        if tokens.len() < 5 {
            return None;
        }

        let rest_idx = char_indices
            .find(|(_, ch)| !ch.is_whitespace())
            .map(|(i, _)| i)
            .unwrap_or(trimmed.len());
        let rest = &trimmed[rest_idx..];

        let timestamp = format!("{} {}", tokens[0], tokens[1]);
        let pid = tokens[2].to_string();
        let tid = tokens[3].to_string();
        let level = LogLevel::from_tag(tokens[4]);

        let (tag, message) = if let Some((t, m)) = rest.split_once(':') {
            (t.trim().to_string(), m.trim_start().to_string())
        } else {
            ("System".to_string(), rest.to_string())
        };

        Some(LogEntry {
            id,
            timestamp,
            pid,
            tid,
            level,
            tag,
            message,
        })
    }
}
