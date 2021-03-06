# encoding: utf-8

require 'spec_helper_min'

module Carto
  describe Notification do
    before(:all) do
      @organization = FactoryGirl.create(:organization)
    end

    after(:all) do
      @organization.destroy
    end

    describe '#validation' do
      it 'passes for valid notification' do
        n = Notification.new(icon: 'ok', body: 'Hello, friend!')
        expect(n).to be_valid
      end

      it 'passes for valid organization notification' do
        n = Notification.new(icon: 'ok', body: 'Hello, friend!', organization: @organization, recipients: 'builders')
        expect(n).to be_valid
      end

      describe 'icon' do
        it 'is required' do
          n = Notification.new
          expect(n).not_to be_valid
          expect(n.errors).to include :icon
        end

        it 'cannot be blank' do
          n = Notification.new(icon: '')
          expect(n).not_to be_valid
          expect(n.errors).to include :icon
        end
      end

      describe 'recipients' do
        it 'is required if organization is present' do
          n = Notification.new(organization: @organization)
          expect(n).not_to be_valid
          expect(n.errors).to include :recipients
        end

        it 'is not required if organization is not present' do
          n = Notification.new
          n.valid?
          expect(n.errors).not_to include :recipients
        end

        it 'does not accept arbitrary values' do
          n = Notification.new(recipients: 'everybody')
          expect(n).not_to be_valid
          expect(n.errors).to include :recipients
        end
      end

      describe 'body' do
        it 'is required' do
          n = Notification.new
          expect(n).not_to be_valid
          expect(n.errors).to include :body
        end

        it 'cannot be empty' do
          n = Notification.new(body: '')
          expect(n).not_to be_valid
          expect(n.errors).to include :body
        end

        it 'cannot be longer than 140 characters' do
          n = Notification.new(body: 'a' * 141)
          expect(n).not_to be_valid
          expect(n.errors).to include :body
        end

        it 'cannot contain Markdown images' do
          n = Notification.new(body: '![this is](an image])')
          expect(n).not_to be_valid
          expect(n.errors).to include :body
        end

        it 'does not count Markdown characters towards length' do
          # Should only count `linkb` (and 135 a's). Ignores the link and `_*`
          n = Notification.new(body: '[link](should not be counted)_*b*_' + 'a' * 135)
          n.valid?
          expect(n.errors).not_to include :body
        end
      end
    end

    it 'should be deleted when the organization is destroyed' do
      org = FactoryGirl.create(:organization)
      n = Notification.create!(organization_id: org.id, icon: 'ok', recipients: 'all', body: 'Hey!')
      org.destroy
      expect(Notification.exists?(n.id)).to be_false
    end
  end
end
