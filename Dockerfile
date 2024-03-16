FROM alpine:3.19.1

LABEL maintainer "ferrari.marco@gmail.com"

# Install the necessary packages
RUN apk add --no-cache \
  dnsmasq \
  wget \
  nfs-utils \
  bash

ENV MEMTEST_VERSION 5.31b
# ENV SYSLINUX_VERSION 6.03
# ENV SYSLINUX_URL https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-"$SYSLINUX_VERSION".tar.gz
ENV SYSLINUX_VERSION 6.04-pre1
ENV SYSLINUX_URL https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/Testing/6.04/syslinux-"$SYSLINUX_VERSION".tar.gz
ENV TEMP_SYSLINUX_PATH /tmp/syslinux-"$SYSLINUX_VERSION"

WORKDIR /tmp
RUN \
  mkdir -p "$TEMP_SYSLINUX_PATH" \
  && wget -q "$SYSLINUX_URL" \
  && tar -xzf syslinux-"$SYSLINUX_VERSION".tar.gz \
  && mkdir -p /var/lib/tftpboot/bios \
  && cp "$TEMP_SYSLINUX_PATH"/bios/core/pxelinux.0 /var/lib/tftpboot/bios/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/libutil/libutil.c32 /var/lib/tftpboot/bios/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/elflink/ldlinux/ldlinux.c32 /var/lib/tftpboot/bios/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/menu/menu.c32 /var/lib/tftpboot/bios/ \
  && mkdir -p /var/lib/tftpboot/efi32 \
  && cp "$TEMP_SYSLINUX_PATH"/efi32/efi/syslinux.efi /var/lib/tftpboot/efi32 \
  && cp "$TEMP_SYSLINUX_PATH"/efi32/com32/libutil/libutil.c32 /var/lib/tftpboot/efi32 \
  && cp "$TEMP_SYSLINUX_PATH"/efi32/com32/menu/menu.c32 /var/lib/tftpboot/efi32 \
  && cp "$TEMP_SYSLINUX_PATH"/efi32/com32/elflink/ldlinux/ldlinux.e32 /var/lib/tftpboot/efi32 \
  && mkdir -p /var/lib/tftpboot/efi64 \
  && cp "$TEMP_SYSLINUX_PATH"/efi64/efi/syslinux.efi /var/lib/tftpboot/efi64 \
  && cp "$TEMP_SYSLINUX_PATH"/efi64/com32/libutil/libutil.c32 /var/lib/tftpboot/efi64 \
  && cp "$TEMP_SYSLINUX_PATH"/efi64/com32/menu/menu.c32 /var/lib/tftpboot/efi64 \
  && cp "$TEMP_SYSLINUX_PATH"/efi64/com32/elflink/ldlinux/ldlinux.e64 /var/lib/tftpboot/efi64 \
  && rm -rf "$TEMP_SYSLINUX_PATH" \
  && rm /tmp/syslinux-"$SYSLINUX_VERSION".tar.gz \
  && wget -q http://www.memtest.org/download/archives/"$MEMTEST_VERSION"/memtest86+-"$MEMTEST_VERSION".bin.gz \
  && gzip -d memtest86+-"$MEMTEST_VERSION".bin.gz \
  && mkdir -p /var/lib/tftpboot/bios/memtest \
  && cp memtest86+-$MEMTEST_VERSION.bin /var/lib/tftpboot/bios/memtest/memtest86+ \
  && mkdir -p /var/lib/tftpboot/efi32/memtest \
  && cp memtest86+-$MEMTEST_VERSION.bin /var/lib/tftpboot/efi32/memtest/memtest86+ \
  && mkdir -p /var/lib/tftpboot/efi64/memtest \
  && cp memtest86+-$MEMTEST_VERSION.bin /var/lib/tftpboot/efi64/memtest/memtest86+ \
  && rm -rf memtest86+-$MEMTEST_VERSION.bin

RUN \
  mkdir -p /var/lib/tftpboot/bios/redorescue \
  && mkdir -p /var/lib/tftpboot/efi32/redorescue \
  && mkdir -p /var/lib/tftpboot/efi64/redorescue

# Configure PXE and TFTP
COPY tftpboot/ /var/lib/tftpboot

COPY redorescue/initrd /var/lib/tftpboot/bios/redorescue
COPY redorescue/vmlinuz /var/lib/tftpboot/bios/redorescue

COPY redorescue/initrd /var/lib/tftpboot/efi32/redorescue
COPY redorescue/vmlinuz /var/lib/tftpboot/efi32/redorescue

# COPY redorescue/initrd /var/lib/tftpboot/efi64/redorescue
# COPY redorescue/vmlinuz /var/lib/tftpboot/efi64/redorescue
# COPY redorescue/EFI /var/lib/tftpboot/efi64/redorescue
# COPY redorescue/boot/grub /var/lib/tftpboot/efi64
COPY redorescue/ /var/lib/tftpboot/efi64

# COPY redorescue/live /redorescue

# Configure DNSMASQ
COPY etc/ /etc

# Start dnsmasq. It picks up default configuration from /etc/dnsmasq.conf and
# /etc/default/dnsmasq plus any command line switch
#ENTRYPOINT ["dnsmasq", "--no-daemon"]
#CMD ["--dhcp-range=192.168.56.2,proxy"]

ENTRYPOINT ["dnsmasq", "--no-daemon"]
CMD ["--dhcp-range=192.168.56.10,192.168.56.200,255.255.255.0"]

#CMD ["/bin/sh"]
