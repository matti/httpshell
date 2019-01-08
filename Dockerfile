FROM ruby:2.6.0

WORKDIR /app
COPY app/Gemfile* ./
RUN bundle install

COPY app .

RUN chmod +x /app/entrypoint.sh
ENTRYPOINT [ "/app/entrypoint.sh" ]