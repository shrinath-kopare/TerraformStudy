resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20241009"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network = "default"
  }
  #allow_stopping_for_update = true
}