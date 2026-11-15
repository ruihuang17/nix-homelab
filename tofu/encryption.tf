variable "state_passphrase" {
  description = "Passphrase for state and plan encryption. Set via TF_VAR_state_passphrase from tofu_ovh_env.age."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_passphrase) >= 16
    error_message = "The passphrase must be at least 16 characters."
  }
}

# Do not rename the key provider or method once state exists: the encrypted
# state stores metadata under these names. Use a fallback block to rotate.
terraform {
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
