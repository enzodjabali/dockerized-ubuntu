ARG UBUNTU_VERSION
FROM ubuntu:${UBUNTU_VERSION}

ARG USERNAME
ARG PASSWORD
ARG RESOLUTION

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-mate-desktop locales sudo tigervnc-standalone-server software-properties-common && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Remove Snap-Based Firefox
RUN apt remove --purge firefox -y && \
    rm -rf /var/cache/snapd/

# Ensure preferences file is clean before modifying it
RUN rm -f /etc/apt/preferences.d/mozilla-firefox

# Add Mozilla's PPA (Non-Snap Version)
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    apt update

# Force APT to Prefer the Non-Snap Version
RUN echo "Package: firefox*" > /etc/apt/preferences.d/mozilla-firefox && \
    echo "Pin: release o=LP-PPA-mozillateam" >> /etc/apt/preferences.d/mozilla-firefox && \
    echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/mozilla-firefox

# Install Firefox Again
RUN apt update && apt install firefox -y

RUN useradd -m $USERNAME -p $(openssl passwd $PASSWORD) && \
    usermod -aG sudo $USERNAME && \
    chsh -s /bin/bash $USERNAME

RUN echo "#!/bin/sh\n\
export XDG_SESSION_DESKTOP=mate\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=MATE\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-mate:/etc/xdg\n\
exec dbus-run-session -- mate-session" > /xstartup && chmod +x /xstartup

RUN mkdir /home/$USERNAME/.vnc && \
    echo $PASSWORD | vncpasswd -f > /home/$USERNAME/.vnc/passwd && \
    chmod 0600 /home/$USERNAME/.vnc/passwd && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc

RUN cp -f /xstartup /home/$USERNAME/.vnc/xstartup

RUN echo "#!/bin/sh\n\
sudo -u $USERNAME -g $USERNAME -- vncserver -rfbport 5902 -geometry $RESOLUTION -depth 24 -verbose -localhost no -autokill no" > /startvnc && chmod +x /startvnc

EXPOSE 5902

CMD service dbus start; /usr/lib/systemd/systemd-logind & /startvnc; bash
