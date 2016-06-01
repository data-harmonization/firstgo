FROM mariadb:10.1

ADD fixtures /fixtures

RUN cat /fixtures/*.sql > /all_fixtures.sql
