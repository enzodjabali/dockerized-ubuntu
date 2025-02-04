FROM ubuntu:22.04

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-mate-desktop locales sudo tigervnc-standalone-server software-properties-common iputils-ping && \
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

ARG USER=testuser
ARG PASS=1234

RUN useradd -m $USER -p $(openssl passwd $PASS) && \
    usermod -aG sudo $USER && \
    chsh -s /bin/bash $USER

RUN echo "#!/bin/sh\n\
export XDG_SESSION_DESKTOP=mate\n\
export XDG_SESSION_TYPE=x11\n\
export XDG_CURRENT_DESKTOP=MATE\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-mate:/etc/xdg\n\
exec dbus-run-session -- mate-session" > /xstartup && chmod +x /xstartup

RUN mkdir /home/$USER/.vnc && \
    echo $PASS | vncpasswd -f > /home/$USER/.vnc/passwd && \
    chmod 0600 /home/$USER/.vnc/passwd && \
    chown -R $USER:$USER /home/$USER/.vnc

RUN cp -f /xstartup /home/$USER/.vnc/xstartup

RUN echo "#!/bin/sh\n\
sudo -u $USER -g $USER -- vncserver -rfbport 5902 -geometry 1920x1080 -depth 24 -verbose -localhost no -autokill no" > /startvnc && chmod +x /startvnc

EXPOSE 5902

CMD service dbus start; /usr/lib/systemd/systemd-logind & /startvnc; bash
