# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bundler::Audit::Fix::CLI do
  let(:bundle)    { 'unpatched_gems' }
  let(:directory) { File.join('spec', 'bundle', bundle) }

  subject do
    described_class.new.invoke(:update, [directory], { database: Fixtures::Database::PATH })
  end

  describe '#update' do
    context 'when exec on secure bundle' do
      let(:bundle) { 'secure' }

      it 'should return exit code 0' do
        expect { subject }.to raise_error do |e|
          expect(e.class).to eq SystemExit
          expect(e.status).to eq 0
        end
      end
    end

    context 'when exec on unpatched bundle' do
      let(:bundle) { 'unpatched_gems' }

      it 'should return exit code 0' do
        expect { subject }.to raise_error do |e|
          expect(e.class).to eq SystemExit
          expect(e.status).to eq 0
        end
      end
    end

    context 'when exec on unpatched(stay) bundle' do
      let(:bundle) { 'unpatched_but_stay_same' }

      it 'should return non-zero exit code' do
        expect { subject }.to raise_error do |e|
          expect(e.class).to eq SystemExit
          expect(e.status).to_not eq 0
        end
      end
    end
  end
end
