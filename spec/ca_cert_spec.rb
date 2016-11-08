require 'spec_helper'

describe BoshConfigResource::CaCert do
  subject(:ca_cert) { described_class.new("fake-ca-cert-contents") }

  describe "path" do
    it "returns path to file with ca cert contents" do
      expect(File.read(ca_cert.path)).to eq("fake-ca-cert-contents")
    end
  end

  describe "cleanup" do
    it "deletes the ca cert file path" do
      ca_cert_path = ca_cert.path
      ca_cert.cleanup
      expect(File.exists?(ca_cert_path)).to be_falsey
    end

    it 'is idempotent' do
      expect { ca_cert.cleanup }.to_not raise_error
    end
  end
end
