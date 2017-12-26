FROM gitlab/gitlab-ce:10.1.3-ce.0

LABEL MAINTAINER="test <test@test.com>"

ENV TMPDIR=/tmp/gitlab-zh
ENV GITLAB_VERSION=v10.1.3

RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
     && echo 'Asia/Shanghai' > /etc/timezonesource /etc/profile

RUN git clone --progress --verbose https://gitlab.com/xhang/gitlab.git $TMPDIR \
    && cd $TMPDIR  \
    && git diff $GITLAB_VERSION..$GITLAB_VERSION-zh > $TMPDIR/$GITLAB_VERSION-zh.diff \
    && cd /opt/gitlab/embedded/service/gitlab-rails && git apply $TMPDIR/$GITLAB_VERSION-zh.diff \
    && rm -rf $TMPDIR

EXPOSE 443 80 22

VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

CMD ["/assets/wrapper"]
