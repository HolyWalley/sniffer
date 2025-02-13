# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LittleSniffer::Adapters::NetHttpAdapter do
  def get_request
    uri = URI.parse('http://localhost:4567/?lang=ruby&author=matz')
    Net::HTTP.get(uri)
  end

  def get_request_dynamic_params
    uri = URI.parse('http://localhost:4567/')
    uri.query = URI.encode_www_form(lang: 'ruby', author: 'matz')
    Net::HTTP.get(uri)
  end

  def post_request
    uri = URI.parse('http://localhost:4567/data?lang=ruby')
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data('author' => 'Matz')
    http.request(request)
  end

  def post_json
    uri = URI.parse('http://localhost:4567/json')
    hash = { 'lang' => 'Ruby', 'author' => 'Matz' }
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'text/json')
    request.body = hash.to_json
    http.request(request)
  end

  let(:handler) do
    Class.new do
      attr_reader :data

      def call(data)
        @data = data
      end
    end.new
  end

  let(:fldr) { "net_http" }

  it 'calls handler and pass data on get request' do
    allow(handler).to receive(:call)

    described_class.new(handler: handler).sniff do
      get_request
    end

    expect(handler).to have_received(:call).with(match_yaml_file("#{fldr}/get_response"))
  end

  it 'calls handler and pass data on get request with dynamic params' do
    allow(handler).to receive(:call)

    described_class.new(handler: handler).sniff do
      get_request_dynamic_params
    end

    expect(handler).to have_received(:call).with(match_yaml_file("#{fldr}/get_response_dynamic"))
  end

  it 'calls handler and pass data on post request' do
    allow(handler).to receive(:call)

    expect(handler.data).to eq(nil)

    described_class.new(handler: handler).sniff do
      post_request
    end

    expect(handler).to have_received(:call).with(match_yaml_file("#{fldr}/post_response"))
  end

  it 'calls handler and pass data on json post request' do
    allow(handler).to receive(:call)

    described_class.new(handler: handler).sniff do
      post_json
    end

    expect(handler).to have_received(:call).with(match_yaml_file("#{fldr}/json_response"))
  end
end
