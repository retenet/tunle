![tunel](https://raw.githubusercontent.com/retenet/tunle/master/assets/logo.png)

[![Build Status](https://travis-ci.org/retenet/tunle.svg?branch=master)](https://travis-ci.org/retenet/tunle)
[![](https://images.microbadger.com/badges/image/retenet/tunle.svg)](https://microbadger.com/images/retenet/tunle "Get your own image badge on microbadger.com")

# What is tunle?

tunle is a Dockerized tunneling tool providing a VPN or Proxy tunnel for all Docker containers. tunle's goal is to provide easy setup for all the most popular VPN providers, across multiple architectures.

# How to Use

Copy one of the samples configs from `configs` for OpenVPN

```bash
docker run -d \
  --rm \
  --name tunle \
  --env-file sample.cfg \
  --device /dev/net/tun \
  --cap-drop all \
  --cap-add MKNOD \
  --cap-add SETUID \
  --cap-add SETGID \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  retenet/tunleV
```

Wireguard Currently only supported with predefined config
```bash
docker run -d \

  --rm \
  --name tunle \
  -e VPN_TYPE=wireguard \
  -v /home/user/wg_vpn:/etc/wireguard \
  --device /dev/net/tun \
  --cap-drop all \
  --cap-add MKNOD \
  --cap-add SETUID \
  --cap-add SETGID \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  retenet/tunle
```


Default Docker Capability List:
* CHOWN
* DAC_OVERRIDE
* FOWNER
* FSETID
* KILL
* SETGID
* SETUID
* SETPCAP
* NET_BIND_SERVICE
* NET_RAW
* SYS_CHROOT
* MKNOD
* AUDIT_WRITE
* SETFCAP

[Full Capablity List](https://man7.org/linux/man-pages/man7/capabilities.7.html)

Now attach the desired container using `--net=container:tunle`
```
docker run -it --rm --net=container:tunle ubuntu:bionic
```

The default provider for tunle is `generic`

**NOTE**: If the container fails to start you may need disable IPv6 by using the arg `--sysctl net.ipv6.conf.all.disable_ipv6=0`. This definitely applies to Hack the Box unless I can get it fixed

### Architectures

- [x] amd64
- [x] arm32v6
- [x] arm32v7
- [x] arm64v8
- [x] i386

### Providers

- [x] Generic OpenVPN Config
- [x] Generic Wireguard Config
- [x] CyberGhost
- [ ] ExpressVPN
- [ ] I2P
- [x] IPVanish
- [x] Private Internet Access
- [x] NordVPN
- [ ] ShadowSocks
- [x] SurfShark
- [x] TunnelBear
- [x] TorGuard
- [x] Tor Transparent Proxy

### Generic Supported Providers

- Hack The Box
- Mullvad
- Others TBD

