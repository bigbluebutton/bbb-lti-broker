# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

#!/bin/sh

if [ "$RAILS_ENV" = "production" ] && [ "$DB_ADAPTER" = "postgresql" ]; then
  while ! curl http://$DB_HOST:-localhost:${DB_PORT:-5432}/ 2>&1 | grep '52'
  do
    echo "Waiting for postgres to start up ..."
    sleep 1
  done
fi

db_create=$(RAILS_ENV=$RAILS_ENV bundle exec rake db:create)
echo $db_create

if [ "$db_create" = "${db_create%"already exists"*}" ]; then
  echo ">>> Database migration"
  bundle exec rake db:migrate
else
  echo ">>> Database initialization"
  bundle exec rake db:schema:load
  bundle exec rake db:seed
fi

# Assets are precompiled on start because the root can change based on ENV["RELATIVE_URL_ROOT"]
echo "Precompile assets..."
bundle exec rake assets:precompile --trace

echo "Start app..."
bundle exec rails s -b 0.0.0.0 -p 3000
