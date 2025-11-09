# flannel-ifcae-docker
for set flannel on nebula interface

docker build -t flannel-ansible:latest .

docker run --rm \
  --privileged \
  --network host \
  --pid host \
  -v /:/host \
  -v /run/systemd:/run/systemd \
  -v /var/run/dbus:/var/run/dbus \
  -v ./ansible-vars-config:/ansible-vars-config:ro \
  flannel-ansible

docker compose run --rm flannel-installer
