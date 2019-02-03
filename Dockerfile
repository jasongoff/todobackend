# Test stage
FROM alpine AS test
LABEL application=todobackend

# Install basic utilities
RUN apk add --no-cache bash git

# Install build dependencies
RUN apk add --no-cache gcc python3-dev libffi-dev musl-dev linux-headers mariadb-dev
RUN pip3 install wheel

COPY /src/requirements* /build/
WORKDIR /build

RUN pip3 wheel -r requirements_test.txt --no-cache-dir --no-input
RUN pip3 install -r requirements_test.txt -f /build --no-index --no-cache-dir

COPY /src /app
WORKDIR /app

CMD ["python3", "manage.py", "test", "--noinput", "--settings=todobackend.settings_test"]

##########################
# Release stage
##########################

FROM alpine
LABEL application=todobackend

# Install OS dependencies
RUN apk add --no-cache python3 mariadb-client bash curl bats jq

# Create app user and group
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app

# Copy and install application source and pre-built dependencies
COPY --from=test --chown=app:app /build /build
COPY --from=test --chown=app:app /app /app
RUN pip3 install -r /build/requirements.txt -f /build --no-index --no-cache-dir
RUN rm -rf /build

# create public volume
RUN mkdir /public
RUN chown app:app public
VOLUME /public

# Set working directory and application user
WORKDIR /app
USER app
