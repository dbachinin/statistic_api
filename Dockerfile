FROM ruby:2.6.3

WORKDIR /code
COPY . /code
RUN gem install bundler
RUN bundle install

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]