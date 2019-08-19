# Paketninja API Client

This client demonstrates the authorization/authentication for the Paketninja API and lists all shipments.
You need the authorization code (first time usage) and the refresh token (subsequent usage). The request token will be
requested automatically if required.

## Usage

```bash
gem install httparty

# With an authorization code (first time usage):
PAKETNINJA_CLIENT_ID="CgU8qexBLjupvEoadMTU9OxAMII1y3UaUlONKWlGvs8" \
PAKETNINJA_CLIENT_SERCRET="rNn-k5pEPTLDpNrXR_9yC7keGi_G4PQs44sVRx3KbG4" \
PAKETNINJA_AUTHORIZATION_CODE="XOXjFt8eopyZ_gkXXyKDDHAgSjBPG6jHFP6rjQjoi08" \
./paketninja_api_client.rb

# Remember the refresh token from last line for later use.

# With a refresh token (subsequent usage):
PAKETNINJA_HOST="paketninja-staging.herokuapp.com" \
PAKETNINJA_CLIENT_ID="CgU8qexBLjupvEoadMTU9OxAMII1y3UaUlONKWlGvs8" \
PAKETNINJA_CLIENT_SERCRET="rNn-k5pEPTLDpNrXR_9yC7keGi_G4PQs44sVRx3KbG4" \
PAKETNINJA_REFRESH_TOKEN="FVwc6aGAFdqosFmSmUiohSSfhGh5QJVoLN5hwDr76rY" \
./paketninja_api_client.rb
```
