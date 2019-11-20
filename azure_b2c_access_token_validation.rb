require 'net/http'
require 'openssl'
require 'base64'
require 'rsa_pem'

class AzureAdJsonWebToken

  def self.rsa_key(kid)
      url = URI.parse('https://AzureB2CTenantName.b2clogin.com/AzureB2CTenantName.onmicrosoft.com/discovery/v2.0/keys?p=AzureB2CWOrkflowPolicyName')
      key_file = JSON.parse(Net::HTTP.get(url))
      key = key_file['keys'].map {|k| k if k["kid"] == kid}.compact.first
      pem_string = RsaPem.from(key["n"], key["e"])
      OpenSSL::PKey::RSA.new pem_string
    end

    def self.decode_with_signature_verification(token)
        token_payload, token_header = self.decode_without_signature(token)
        kid = token_header["kid"]
        verification = self.rsa_key(kid)
        JWT.decode(token, verification, true, { algorithm: 'RS256',
                                                aud: token_payload["aud"],
                                                verify_aud: true,
                                                iss: token_payload["iss"],
                                                verify_iss: true 
                                              })
    end

    def self.decode_without_signature(token)
      JWT.decode(token, nil, false)
    end

  end