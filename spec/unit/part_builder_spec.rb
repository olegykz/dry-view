RSpec.describe Dry::View::PartBuilder do
  subject(:part_builder) { described_class.new(namespace: namespace) }

  let(:namespace) { nil }

  describe '#call' do
    subject(:part) { part_builder.(name: name, value: value, renderer: renderer, context: context, **options) }

    let(:name) { :user }
    let(:value) { double(:user) }
    let(:renderer) { double(:renderer) }
    let(:context) { double(:context) }
    let(:options) { {} }

    shared_examples 'a view part' do
      let(:part_class) { Dry::View::Part }

      it 'returns a part' do
        expect(part).to be_a part_class
      end

      it 'wraps the value' do
        expect(part._value).to eq value
      end

      it 'retains the part builder' do
        expect(part._part_builder).to eql part_builder
      end
    end

    shared_examples 'a view part collection' do
      let(:collection_part_class) { Dry::View::Part }
      let(:item_part_class) { Dry::View::Part }

      it 'returns a part wrapping the collection' do
        expect(part).to be_a collection_part_class
      end

      it 'wraps the collection and its items' do
        expect(part._value.map(&:_value)).to eq value
      end

      it "returns the collection's items as parts" do
        part.to_a.each do |item|
          expect(item).to be_a item_part_class
        end
      end
    end

    context 'without namespace' do
      describe 'singular value' do
        let(:value) { double('user') }

        it_behaves_like 'a view part'

        describe 'alternative name provided via :as option' do
          let(:options) { {as: :admin_user} }

          it_behaves_like 'a view part'
        end

        describe 'explicit part class provided via as: option' do
          before do
            Test::UserPart = Class.new(Dry::View::Part)
          end

          let(:options) { {as: Test::UserPart} }

          it_behaves_like 'a view part' do
            let(:part_class) { Test::UserPart }
          end
        end
      end

      describe 'array-like value' do
        let(:name) { :users }
        let(:value) { [double(:user), double(:user)] }

        it_behaves_like 'a view part collection'

        describe 'alternative name provided via :as option' do
          let(:options) { {as: :admin_user} }

          it_behaves_like 'a view part collection'
        end

        describe 'explicit part class provided via as: option' do
          before do
            Test::UserPart = Class.new(Dry::View::Part)
          end

          let(:options) { {as: Test::UserPart} }

          it_behaves_like 'a view part collection' do
            let(:item_part_class) { Test::UserPart }
          end
        end

        describe 'explicit collection part class provided via as: option' do
          before do
            Test::UserCollectionPart = Class.new(Dry::View::Part)
          end

          let(:options) { {as: [Test::UserCollectionPart]} }

          it_behaves_like 'a view part collection' do
            let(:collection_part_class) { Test::UserCollectionPart }
          end
        end
      end
    end

    context 'with namespace' do
      before do
        module Test
          module Parts
            class Users < Dry::View::Part
            end

            class UserCollection < Dry::View::Part
            end

            class User < Dry::View::Part
              decorate :profile
            end

            class AdminUser < Dry::View::Part
            end

            module UserModule
            end

            class Profile < Dry::View::Part
            end
          end
        end
      end

      let(:namespace) { Test::Parts }

      describe 'singular value' do
        let(:value) { double('user', profile: 'profile') }

        it_behaves_like 'a view part' do
          let(:part_class) { Test::Parts::User }
        end

        it 'returns decorated attributes in part classes found from the namespace' do
          expect(part.profile).to be_a Test::Parts::Profile
        end

        describe 'alternative name provided via :as option' do
          let(:options) { {as: :admin_user} }

          it_behaves_like 'a view part' do
            let(:part_class) { Test::Parts::AdminUser }
          end
        end

        describe 'alternative name provided via :as option, when matched constant is not a class inheriting from Dry::View::Part' do
          let(:options) { {as: :user_module} }

          it_behaves_like 'a view part' do
            let(:part_class) { Dry::View::Part }
          end
        end

        describe 'explicit part class provided via as: option' do
          let(:options) { {as: Test::Parts::AdminUser} }

          it_behaves_like 'a view part' do
            let(:part_class) { Test::Parts::AdminUser }
          end
        end
      end

      describe 'array-like value' do
        let(:name) { :users }
        let(:value) { [double(:user), double(:user)] }

        it_behaves_like 'a view part collection' do
          let(:collection_part_class) { Test::Parts::Users }
          let(:item_part_class) { Test::Parts::User }
        end

        describe 'alternative element name provided via :as option' do
          let(:options) { {as: :admin_user} }

          it_behaves_like 'a view part collection' do
            let(:collection_part_class) { Test::Parts::Users }
            let(:item_part_class) { Test::Parts::AdminUser }
          end
        end

        describe 'alternative collection name provided via :as option' do
          let(:options) { {as: [:user_collection]} }

          it_behaves_like 'a view part collection' do
            let(:collection_part_class) { Test::Parts::UserCollection }
            let(:item_part_class) { Test::Parts::User }
          end
        end

        describe 'alternative collection and element names provided via :as option' do
          let(:options) { {as: [:user_collection, :admin_user]} }

          it_behaves_like 'a view part collection' do
            let(:collection_part_class) { Test::Parts::UserCollection }
            let(:item_part_class) { Test::Parts::AdminUser }
          end
        end

        describe 'explicit part class provided via as: option' do
          let(:options) { {as: Test::Parts::AdminUser} }

          it_behaves_like 'a view part collection' do
            let(:collection_part_class) { Test::Parts::Users }
            let(:item_part_class) { Test::Parts::AdminUser }
          end
        end

        describe 'explicit collection part class provided via as: option' do
          let(:options) { {as: [Test::Parts::UserCollection]} }

          it_behaves_like 'a view part collection' do
            let(:collection_part_class) { Test::Parts::UserCollection }
            let(:item_part_class) { Test::Parts::User }
          end
        end

        describe 'explicit collection and element part classes provided via :as option' do
          let(:options) { {as: [Test::Parts::UserCollection, Test::Parts::AdminUser]} }

          it_behaves_like 'a view part collection' do
            let(:collection_part_class) { Test::Parts::UserCollection }
            let(:item_part_class) { Test::Parts::AdminUser }
          end
        end
      end
    end
  end
end
