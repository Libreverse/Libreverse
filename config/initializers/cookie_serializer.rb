# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are:
# - :json (safest, but can only serialize basic data types)
# - :marshal (most compatible, but potentially dangerous)
# - :hybrid (fallback mechanism that reads marshal cookies but writes json cookies)
#
# Using :json is the most secure option as it limits the risk of deserialization attacks
# that could occur with :marshal.

Rails.application.config.action_dispatch.cookies_serializer = :json

# Use SHA256 for signed cookies for improved security over the default SHA1
Rails.application.config.action_dispatch.signed_cookie_digest = "SHA256"

# Do not allow JavaScript to access cookies for added security
Rails.application.config.action_dispatch.cookies_same_site_protection = :strict
