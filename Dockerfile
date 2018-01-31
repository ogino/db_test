FROM jruby:latest

ENV APP_ROOT /usr/src/proxy_test

WORKDIR $APP_ROOT

COPY . $APP_ROOT

RUN gem install bundler

RUN rm -rf logs && \
    rm -rf vendor

RUN bundle install --path --path vendor/bundler && \
    rm -rf ~/.gem && \
    mkdir logs

CMD ["bundle", "exec", "rackup", "-p", "80", "-E", "production", "-o", "0.0.0.0"]