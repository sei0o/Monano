require 'net/http'
require 'uri'
require 'json'

class MonacoinRPC
  def initialize(service_url)
    @uri = URI.parse(service_url)
  end

  def method_missing(name, *args)
    post_body = {'method' => name, 'params' => args, 'id' => 'jsonrpc'}.to_json
    resp = JSON.parse(http_post_request(post_body))
    puts resp['error'] if resp['error']
    resp['result']
  end

  def http_post_request(post_body)
    http    = Net::HTTP.new(@uri.host, @uri.port)
    request = Net::HTTP::Post.new(@uri.request_uri)
    request.basic_auth @uri.user, @uri.password
    request.content_type = 'application/json'
    request.body = post_body
    http.request(request).body
  end

  class JSONRPCError < RuntimeError; end
end

if __FILE__ == $0
  wallet = MonacoinRPC.new('http://monacoinrpc:EJ6aJgxqFgUMsE2oQPMrzmXHC3BRXfzaLNXJeURiUkSg@127.0.0.1:10010')
  p wallet.getbalance
end