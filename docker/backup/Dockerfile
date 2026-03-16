FROM postgres:17-alpine

RUN apk add --no-cache aws-cli bash

COPY backup.sh /backup.sh
COPY run.sh /run.sh
RUN chmod +x /backup.sh /run.sh

CMD ["/run.sh"]
