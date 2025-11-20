require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user, first_name: 'John', last_name: 'Doe') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:encrypted_password) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:leads).with_foreign_key(:assigned_to_id) }
    it { is_expected.to have_many(:activities) }
  end

  describe '#full_name' do
    context 'with both first and last name' do
      it 'returns concatenated name' do
        result = user.full_name

        expect(result).to eq('John Doe')
      end
    end

    context 'with missing last name' do
      before { user.last_name = nil }

      it 'returns only first name' do
        result = user.full_name

        expect(result).to eq('John')
      end
    end

    context 'with blank last name' do
      before { user.last_name = '' }

      it 'returns only first name' do
        result = user.full_name

        expect(result).to eq('John')
      end
    end
  end

  describe 'approval workflow' do
    describe '#active_for_authentication?' do
      context 'when user is approved' do
        before { user.approved = true }

        it 'returns true' do
          expect(user).to be_active_for_authentication
        end
      end

      context 'when user is not approved' do
        before { user.approved = false }

        it 'returns false' do
          expect(user).not_to be_active_for_authentication
        end
      end
    end

    describe '#inactive_message' do
      context 'when user is not approved' do
        before { user.approved = false }

        it 'returns not_approved message' do
          result = user.inactive_message

          expect(result).to eq(:not_approved)
        end
      end

      context 'when user is approved' do
        before { user.approved = true }

        it 'returns default inactive message' do
          allow(user).to receive(:active_for_authentication?).and_return(false)

          result = user.inactive_message

          expect(result).to eq(:inactive)
        end
      end
    end
  end

  describe 'admin functionality' do
    describe 'default admin status' do
      it 'defaults to false' do
        user = build(:user)

        expect(user.admin).to be false
      end
    end

    describe 'admin trait' do
      it 'can be created as admin' do
        admin_user = build(:user, :admin)

        expect(admin_user.admin).to be true
      end
    end
  end

  describe 'approval status' do
    describe 'default approval status' do
      it 'defaults to true' do
        user = build(:user)

        expect(user.approved).to be true
      end
    end

    describe 'unapproved trait' do
      it 'can be created as unapproved' do
        unapproved_user = build(:user, :unapproved)

        expect(unapproved_user.approved).to be false
      end
    end
  end
end
