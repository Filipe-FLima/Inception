FROM   debian:bookworm

RUN apt-update -y && \
    apt-get install mariadb-server -y && \
	rm -rf /var/lib/apt/lists/*

COPY    ./conf/mariadb.cnf /etc/mysql/mariadb.conf.d
RUN     chmod 644 /etc/mysql/mariadb.conf.d/mariadb.cnf

COPY ./tools/mdb-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mdb-setup.sh

ENTRYPOINT ["/usr/local/bin/mdb-setup.sh"]

EXPOSE 3306

CMD ["--bind-address=0.0.0.0", "--port=3306"]