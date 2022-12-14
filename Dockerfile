FROM python:alpine AS requirements

ENV PYTHONDONTWRITEBYTECODE 1

RUN python -m pip install --quiet -U pip poetry

WORKDIR /src

COPY pyproject.toml pyproject.toml
COPY poetry.lock poetry.lock

RUN poetry export --quiet --no-interaction -f requirements.txt --without-hashes -o /src/requirements.txt

# now we create our final container, runtime
FROM python:alpine AS runtime

WORKDIR /app

# now we use multistage containers to then copy the requirements from the other container
COPY --from=requirements /src/requirements.txt .

# now we're *just* deploying the needed packages for whatever was in the poetry setup
RUN python -m pip install --quiet -U pip
RUN pip install -r requirements.txt

COPY main.py .

ENTRYPOINT ["python /app/main.py"]