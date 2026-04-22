# Stopper les 3 services dans l'ordre
sudo systemctl stop docker.socket
sudo systemctl stop docker
sudo systemctl stop containerd


# Ecrire la config
sudo tee /etc/docker/daemon.json <<'EOF'
{
  "features": {
    "containerd-snapshotter": false
  }
}
EOF

# Purger le content store corrompu
sudo rm -rf /var/lib/docker/containerd/

# Redémarrer dans l'ordre
sudo systemctl start containerd
sudo systemctl start docker

# Vérifier
sudo docker info | grep "Storage Driver"