FROM alpine:latest

RUN apk update && apk add --no-cache python3 curl git rclone \
    && ln -sf python3 /usr/bin/python \
    && apk add --no-cache py3-pip py3-setuptools  py3-virtualenv \
    && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin latest \
    && apk add --no-cache go \
    && mkdir -p /go \
    && echo "export GOPATH=/go" >> /etc/profile \
    && echo "export PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin" >> /etc/profile \
    && source /etc/profile

RUN apk add --no-cache docker openrc && rc-update add docker boot
RUN wget -O - -q https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s v2.18.2
RUN gosec --help
RUN python3 -m venv /venv \
    && . /venv/bin/activate \
    && pip install --no-cache-dir semgrep \
    && deactivate
WORKDIR /app
COPY entrypoint.sh .

ENTRYPOINT ["/app/entrypoint.sh"]

