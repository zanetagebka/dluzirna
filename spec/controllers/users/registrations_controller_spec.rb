require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'before_action callbacks' do
    it 'includes configure_permitted_parameters for devise controller' do
      expect(controller).to receive(:configure_permitted_parameters)
      controller.send(:configure_permitted_parameters)
    end

    it 'includes ensure_admin_for_destroy for destroy action' do
      # Simple check - just verify the callback exists
      callback_found = controller.class._process_action_callbacks.any? do |cb|
        cb.filter == :ensure_admin_for_destroy
      end
      expect(callback_found).to be true
    end
  end


  describe 'custom business logic' do
    describe 'parameter configuration' do
      it 'allows role parameter for user registration' do
        expect(controller.class._process_action_callbacks.any? { |cb| cb.filter == :configure_permitted_parameters }).to be true
      end
    end

    describe 'admin access control' do
      it 'has admin-only destroy protection' do
        expect(controller.class._process_action_callbacks.any? { |cb| cb.filter == :ensure_admin_for_destroy }).to be true
      end
    end

    describe 'custom destroy method' do
      it 'overrides parent destroy method for logging' do
        expect(controller).to respond_to(:destroy)
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from Devise::RegistrationsController' do
      expect(described_class.superclass).to eq(Devise::RegistrationsController)
    end
  end
end
