# encoding: utf-8

require 'spec_helper'

describe "GET params" do

  it "supports params like /hello/:name" do
    app = Sinatra.new do
      get '/Hello/:name' do
        [ 201, {}, ["Hello #{params[:name]}!"] ]
      end
    end
    response = app.call 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/Hello/Horst', 'rack.input' => ''
    expect(response[2]).to be == ["Hello Horst!"]
  end

  it "exposes params with indifferent hash" do
    app = Sinatra.new do
      get '/:foo' do
        bar = params['foo']
        bar = params[:foo]
        [ 201, {}, 'ok' ]
      end
    end
    response = app.call 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/bar', 'rack.input' => ''
    expect(response[2]).to be == ['ok']
  end

  it "merges named params and query string params in params" do
    app = Sinatra.new do
      get '/:foo' do
        bar = params['foo']
        biz = params[:bar]
        [ 201, {}, '' ]
      end
    end
    response = app.call 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/biz', 'rack.input' => ''
    expect(response[0]).to be == 201
  end

  it "supports optional named params like /?:foo?/?:bar?" do
    app = Sinatra.new do
      get '/?:foo?/?:bar?' do
        [ 201, {}, ["foo=#{params[:foo]};bar=#{params[:bar]}"] ]
      end
    end
    response = app.call 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/hello/world', 'rack.input' => ''
    expect(response[2]).to be == ["foo=hello;bar=world"]

    response = app.call 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/hello', 'rack.input' => ''
    expect(response[2]).to be == ["foo=hello;bar="]

    response = app.call 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/', 'rack.input' => ''
    expect(response[2]).to be == ["foo=;bar="]
  end

  context "nested params" do
    def app
      @app
    end
    # this is throwing an error. it seems that 'expect' doesn't work within a sinatra route handler (i.e the get block)
    it("exposes nested params with indifferent hash") do
      verifier = Proc.new { |params|
        expect(params["bar"][0][:foo]).to eql("baz")
        expect(params["bar"][0]["foo"]).to eql("baz")
      }
      @app = Sinatra.new do
        get '/foo' do
          verifier.call(params)
          [201, {}, '']
        end
      end
      response = get '/foo?bar[][foo]=baz'
      expect(response.status).to be == 201
    end

    it("supports arrays within params") do
      verifier = Proc.new { |params|
        expect(params[:bar]).to be == ["A", "B"]
      }
      @app = Sinatra.new do
        get '/foo' do
          verifier.call(params)
          [201, {}, '']
        end
      end
      response = get '/foo?bar[]=A&bar[]=B'
      expect(response.status).to be == 201
    end

    it "supports deeply nested params" do
      expected_params = {
                      "emacs" => {
                                  "map"     => { "goto-line" => "M-g g" },
                                  "version" => "22.3.1"
                                  },
                      "browser" => {
                                  "firefox" => {"engine" => {"name"=>"spidermonkey", "version"=>"1.7.0"}},
                                  "chrome"  => {"engine" => {"name"=>"V8", "version"=>"1.0"}}
                                  },
                      "paste" => {"name"=>"hello world", "syntax"=>"ruby"}
      }

      verifier = ->(params) { expect(params).to be == expected_params }
      @app = Sinatra.new do
        get '/foo' do
          verifier.call(params)
          [201, {}, '']
        end
      end
      response = get '/foo', expected_params
      expect(response.status).to be == 201
    end
  end
    

  context "non-nested params" do
    let(:app) do
      Sinatra.new do
        get '/foo' do
          [ 201, {}, "#{params['article_id']}; #{params['comment']['body']}" ]
        end
      end
    end
    let(:response){ get '/foo?article_id=2&comment[body]=awesome' }
    it("preserves non-nested params") { expect(response.status).to be == 201 }
    it("preserves non-nested params") { expect(response.body).to be == "2; awesome" }
  end
end
