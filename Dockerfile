ARG ALPINE_VERSION=3.16

FROM python:3.9.13-alpine AS requirements

ENV PYTHONDONTWRITEBYTECODE 1

RUN python -m pip install --quiet -U pip poetry

WORKDIR /src

COPY pyproject.toml pyproject.toml
COPY poetry.lock poetry.lock

RUN poetry export --quiet --no-interaction -f requirements.txt --without-hashes -o /src/requirements.txt

FROM python:3.10.5-alpine${ALPINE_VERSION} as aws-builder

WORKDIR /src

ARG AWS_CLI_VERSION=2.7.21
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake
RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git

WORKDIR /src/aws-cli
RUN sed -i'' 's/PyInstaller.*/PyInstaller==5.2/g' requirements-build.txt
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

# reduce image size: remove autocomplete and examples
RUN rm -rf /usr/local/aws-cli/v2/current/dist/aws_completer /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

# now we create our final container, runtime
FROM python:3.9.13-alpine AS runtime

COPY --from=aws-builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=aws-builder /aws-cli-bin/ /usr/local/bin/

# now we use multistage containers to then copy the requirements from the other container
COPY --from=requirements /src/requirements.txt .

# now we're *just* deploying the needed packages for whatever was in the poetry setup
RUN python -m pip install --quiet -U pip
RUN pip install -r requirements.txt

COPY main.py /app/main.py

WORKDIR /app/

ENTRYPOINT ["python /app/main.py"]