FROM agreenspan/drawbase:first
MAINTAINER agreenspan
ENV RAILS_ENV 'production'

WORKDIR /usr/src/app/

COPY Gemfile /usr/src/app/

COPY Gemfile.lock /usr/src/app/

#RUN deploy link_shared_paths
RUN bundle install
#COPY . /usr/src/app
#RUN cd /usr/src/app/
#RUN bundle exec rake assets:precompile
#RUN bundle exec rake db:migrate --trace
#RUN deploy cleanup

COPY . /usr/src/app

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]