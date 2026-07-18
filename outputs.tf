output "id" {
  description = "Identifier of the build trigger."
  value       = google_cloudbuild_trigger.this.id
}

output "trigger_id" {
  description = "Unique id of the build trigger."
  value       = google_cloudbuild_trigger.this.trigger_id
}

output "name" {
  description = "Name of the build trigger."
  value       = google_cloudbuild_trigger.this.name
}
