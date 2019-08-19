#!/usr/bin/env ruby
# frozen_string_literal: true

require "httparty"

class PaketninjaApiClient
  def initialize(
    host: ENV.fetch("PAKETNINJA_HOST"),
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
    authorization_code: ENV["PAKETNINJA_AUTHORIZATION_CODE"],
    refresh_token: ENV["PAKETNINJA_REFRESH_TOKEN"]
  )
    @host = host || "www.paket.ninja"
    if authorization_code
      response = request_access_token(redirect_uri: redirect_uri, authorization_code: authorization_code)
      @access_token = response["access_token"],
      @refresh_token = response["refresh_token"],
      @access_token_expires_at = Time.at(response["created_at"] + response["expires_in"]).to_datetime
    else
      @refresh_token = refresh_token
      @access_token_expires_at = Time.now.to_datetime
    end
  end

  def request_access_token(redirect_uri: "urn:ietf:wg:oauth:2.0:oob", authorization_code: nil)
    HTTParty.post(
      "https://#{@host}/oauth/token",
      {
        headers: {
          "content-type": "application/x-www-form-urlencoded",
        },
        query: {
          client_id: ENV["PAKETNINJA_CLIENT_ID"],
          client_secret: ENV["PAKETNINJA_CLIENT_SERCRET"],
          redirect_uri: redirect_uri,
          grant_type: (authorization_code ? "authorization_code" : "refresh_token"),
          code: authorization_code,
          refresh_token: (@refresh_token unless authorization_code),
        },
        logger: Logger.new(STDOUT),
        log_level: :debug,
        log_format: :curl,
      }.compact,
    ).tap { |response| response.ok? || raise(CouldNotReceiveAccessTokenError, response.code) }.parsed_response
  rescue HTTParty::Error, Errno::ECONNREFUSED, Timeout::Error, SocketError, Encoding::CompatibilityError => e
    Logger.new(STDOUT).warn(e)
    raise CouldNotReceiveAccessTokenError.new(e)
  end

  def refresh_token
    @refresh_token
  end

  def get_shipments
    api_request(
      method: :get,
      uri_path: "/api/v1/shipments",
      error_class: CouldNotReceiveShipmentsError,
    )
  end

  def api_request(method:, uri_path:, data: nil, expected_status: 200, error_class:)
    2.times do
      return try_api_request(
        method: method,
        uri_path: uri_path,
        data: data,
        expected_status: expected_status,
        error_class: error_class,
      )
    rescue UnauthorizedError
      response = request_access_token
      @access_token = response["access_token"]
      @refresh_token = response["refresh_token"]
    end
  end

  private

  def try_api_request(method:, uri_path:, data:, expected_status: 200, error_class:)
    if @access_token.nil? || @access_token_expires_at < Time.now.to_datetime
      response = request_access_token
      @access_token = response["access_token"]
      @refresh_token = response["refresh_token"]
    end

    authenticated_api_request(
      method: method,
      uri: "https://#{@host}#{uri_path}",
      access_token: @access_token,
      body: data,
      expected_status: expected_status,
      error_class: error_class,
    )
  end

  def authenticated_api_request(method:, uri:, access_token:, body: nil, expected_status: 200, error_class:)
    HTTParty.send(
      method,
      uri,
      {
        headers: {
          accept: "application/hal+json",
          "content-type": "application/json",
          authorization: "Bearer #{access_token}",
        },
        body: body&.to_json,
        logger: Logger.new(STDOUT),
        log_level: :debug,
        log_format: :curl,
      }.compact,
    ).tap do |response|
      response.unauthorized? && raise(UnauthorizedError)
      response.not_found? && raise(NotFoundError)
      response.code == expected_status || raise(error_class.send(:with_response, response))
    end.parsed_response
  rescue HTTParty::Error, Errno::ECONNREFUSED, Timeout::Error, SocketError, Encoding::CompatibilityError => e
    Logger.new(STDOUT).warn(e)
    raise error_class.new(e)
  end
end

class UnauthorizedError < StandardError; end

class NotFoundError < StandardError; end

class HttpError < StandardError
  def self.with_response(response)
    new("HTTP status code #{response.code}")
  end
end

class CouldNotReceiveAccessTokenError < HttpError
  def initialize(message)
    super("receive access token failed with: #{message}")
  end
end

class CouldNotReceiveShipmentsError < HttpError
  def initialize(message)
    super("receive shipments failed with: #{message}")
  end
end

client = PaketninjaApiClient.new
puts client.get_shipments
puts "Store the refresh token '#{client.refresh_token}' for later use."
