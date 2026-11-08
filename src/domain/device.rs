use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct AdbDevice {
    pub id: String,
    pub model: String,
}

impl AdbDevice {
    pub fn new(id: impl Into<String>, model: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            model: model.into(),
        }
    }

    pub fn display_name(&self) -> String {
        if self.model.is_empty() {
            self.id.clone()
        } else {
            format!("{} ({})", self.model, self.id)
        }
    }
}
