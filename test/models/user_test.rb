require 'test_helper'

class UserTest < ActiveSupport::TestCase
    test 'Valid user saves successfully' do
        assert_nothing_raised do
            User.new( username: 'foo', email: 'foo@bar.com', password: 'foobarbaz' ).save!
        end
    end
    test 'User save fails because it has no username' do
        assert_raises ActiveRecord::RecordInvalid do
            User.new( email: 'foo@bar.com', password: 'foobarbaz' ).save!
        end
    end
    test 'User save fails because it has no email' do
        assert_raises ActiveRecord::RecordInvalid do
            User.new( username: 'foo', password: 'foobarbaz' ).save!
        end
    end

    test 'User save fails because it has no password' do
        assert_raises ActiveRecord::RecordInvalid do
            User.new( username: 'foo', email: 'foo@bar.com' ).save!
        end
    end

    test 'User save fails because its password is too short' do
        assert_raises ActiveRecord::RecordInvalid do
            User.new( username: 'foo', email: 'foo@bar.com', password: 'foobar' ).save!
        end
    end
end
