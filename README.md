# Rewards Redemption

## Author
- Zoli Szucs

## Installation
Note:  tested using the Mac's built-in Terminal

1. Clone the repository
   `git clone  https://github.com/zs-dev/rewards-redemption-rails-app.git`
2. cd to project root eg  cd Desktop/rewards-redemption-app
3. Run `docker-compose up -d`
4. Run migrations and seed data:
```
docker-compose exec app bin/rails db:drop db:create db:migrate db:seed && docker-compose exec app bundle exec rails db:migrate RAILS_ENV=test

```
Note: these commands can be run multiple times to reset the data to the default.

5. To run console command:
   `docker-compose exec -it app bundle exec rails utils:rewards_redemption`

From here it is straight forward to use it.

6. To run tests:
   `docker-compose exec app bundle exec rspec --fail-fast`
7. DB connections for a client:
```
//dev db

Host: 127.0.0.1

Port: 3306

Username: root

Password: secret

Default Schema: rails_db

//test db

Host: 127.0.0.1

Port: 3307

Username: root

Password: secret

Default Schema: rails_test_db
```
