# frozen_string_literal: true

require 'spec_helper'
require 'bundler/audit/scanner'
require 'bundler/audit/cli/formats'
require 'bundler/audit/cli/formats/text'

RSpec.describe Bundler::Audit::Fix::Patcher do
  let(:bundle)    { 'unpatched_gems' }
  let(:directory) { File.join('spec', 'bundle', bundle) }
  let(:scanner)   { Scanner.new(directory) }

  subject do
    scanner.scan
    described_class.new(directory, scanner.report)
  end

  describe '#patch' do
    it 'should return results' do
      result = subject.patch

      expect(result).not_to be_empty
    end

    it 'should rewrite Gemfile' do
      subject.patch

      original_gemfile = File.read(File.join(directory, 'Gemfile.bak'))
      patched_gemfile  = File.read(File.join(directory, 'Gemfile'))

      expect(patched_gemfile).not_to eq original_gemfile
    end

    context 'when exec on secure bundle' do
      let(:bundle) { 'secure' }

      it 'should return empty results' do
        result = subject.patch

        expect(result).to be_empty
      end
    end

    context 'when exec on unpatched bundle' do
      let(:bundle) { 'unpatched_gems_with_replacement' }

      it 'should return empty results' do
        result = subject.patch

        expect(result).not_to be_empty
      end

      it 'should rewrite Gemfile' do
        subject.patch

        original_gemfile = File.read(File.join(directory, 'Gemfile.bak'))
        patched_gemfile  = File.read(File.join(directory, 'Gemfile'))

        expect(patched_gemfile).not_to eq original_gemfile
      end
    end
  end
end
