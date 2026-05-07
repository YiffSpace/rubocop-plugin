# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::YiffSpace::CurrentUserOutsideOfRequests, :config) do
  let(:config) do
    RuboCop::Config.new(
      "YiffSpace/CurrentUserOutsideOfRequests" => {
        "ClassName"             => "CurrentUser",
        "IgnoredMethods"        => [],
        "IgnoredMethodPrefixes" => [],
        "IgnoredMethodSuffixes" => [],
        "IgnoredMethodPatterns" => [],
      },
    )
  end

  it("registers an offense for CurrentUser.method calls in a regular method") do
    expect_offense(<<~RUBY)
      def process
        CurrentUser.id
        ^^^^^^^^^^^^^^ `CurrentUser` should only be used within the request cycle (controllers, views, helpers, decorators)
      end
    RUBY
  end

  it("registers an offense for a bare CurrentUser constant reference") do
    expect_offense(<<~RUBY)
      def process
        user = CurrentUser
               ^^^^^^^^^^^ `CurrentUser` should only be used within the request cycle (controllers, views, helpers, decorators)
      end
    RUBY
  end

  it("does not register an offense when CurrentUser is used inside its own class definition") do
    expect_no_offenses(<<~RUBY)
      class CurrentUser
        def self.id
          RequestStore[:current_user]&.id
        end
      end
    RUBY
  end

  it("does not register an offense inside a qualified class definition matching ClassName") do
    expect_no_offenses(<<~RUBY)
      class Logical::CurrentUser
        def self.email
          RequestStore[:current_user]&.email
        end
      end
    RUBY
  end

  context("when ClassName is a fully-qualified nested constant") do
    let(:config) do
      RuboCop::Config.new(
        "YiffSpace/CurrentUserOutsideOfRequests" => {
          "ClassName"             => "Logical::CurrentUser",
          "IgnoredMethods"        => [],
          "IgnoredMethodPrefixes" => [],
          "IgnoredMethodSuffixes" => [],
          "IgnoredMethodPatterns" => [],
        },
      )
    end

    it("does not register an offense inside the matching nested class definition") do
      expect_no_offenses(<<~RUBY)
        module Logical
          class CurrentUser
            def self.email
              RequestStore[:current_user]&.email
            end
          end
        end
      RUBY
    end

    it("does not register an offense for a bare CurrentUser reference outside the Logical namespace") do
      expect_no_offenses(<<~RUBY)
        def process
          CurrentUser.id
        end
      RUBY
    end

    it("registers an offense for CurrentUser inside the Logical namespace") do
      expect_offense(<<~RUBY)
        module Logical
          def self.process
            CurrentUser.id
            ^^^^^^^^^^^^^^ `Logical::CurrentUser` should only be used within the request cycle (controllers, views, helpers, decorators)
          end
        end
      RUBY
    end
  end

  it("registers an offense even when deeply nested in another class") do
    expect_offense(<<~RUBY)
      class PostService
        def call
          CurrentUser.id
          ^^^^^^^^^^^^^^ `CurrentUser` should only be used within the request cycle (controllers, views, helpers, decorators)
        end
      end
    RUBY
  end

  context("with IgnoredMethods") do
    let(:config) do
      RuboCop::Config.new(
        "YiffSpace/CurrentUserOutsideOfRequests" => {
          "ClassName"             => "CurrentUser",
          "IgnoredMethods"        => ["serializable_hash"],
          "IgnoredMethodPrefixes" => [],
          "IgnoredMethodSuffixes" => [],
          "IgnoredMethodPatterns" => [],
        },
      )
    end

    it("does not register an offense in an ignored method") do
      expect_no_offenses(<<~RUBY)
        def serializable_hash
          CurrentUser.id
        end
      RUBY
    end

    it("still registers an offense in a non-ignored method") do
      expect_offense(<<~RUBY)
        def process
          CurrentUser.id
          ^^^^^^^^^^^^^^ `CurrentUser` should only be used within the request cycle (controllers, views, helpers, decorators)
        end
      RUBY
    end
  end

  context("with IgnoredMethodPrefixes") do
    let(:config) do
      RuboCop::Config.new(
        "YiffSpace/CurrentUserOutsideOfRequests" => {
          "ClassName"             => "CurrentUser",
          "IgnoredMethods"        => [],
          "IgnoredMethodPrefixes" => ["apionly_"],
          "IgnoredMethodSuffixes" => [],
          "IgnoredMethodPatterns" => [],
        },
      )
    end

    it("does not register an offense in a method matching the prefix") do
      expect_no_offenses(<<~RUBY)
        def apionly_serialize
          CurrentUser.id
        end
      RUBY
    end

    it("still registers an offense in a method not matching the prefix") do
      expect_offense(<<~RUBY)
        def process
          CurrentUser.id
          ^^^^^^^^^^^^^^ `CurrentUser` should only be used within the request cycle (controllers, views, helpers, decorators)
        end
      RUBY
    end
  end

  context("with IgnoredMethodSuffixes") do
    let(:config) do
      RuboCop::Config.new(
        "YiffSpace/CurrentUserOutsideOfRequests" => {
          "ClassName"             => "CurrentUser",
          "IgnoredMethods"        => [],
          "IgnoredMethodPrefixes" => [],
          "IgnoredMethodSuffixes" => ["_current"],
          "IgnoredMethodPatterns" => [],
        },
      )
    end

    it("does not register an offense in a method matching the suffix") do
      expect_no_offenses(<<~RUBY)
        def user_current
          CurrentUser.id
        end
      RUBY
    end
  end

  context("with IgnoredMethodPatterns") do
    let(:config) do
      RuboCop::Config.new(
        "YiffSpace/CurrentUserOutsideOfRequests" => {
          "ClassName"             => "CurrentUser",
          "IgnoredMethods"        => [],
          "IgnoredMethodPrefixes" => [],
          "IgnoredMethodSuffixes" => [],
          "IgnoredMethodPatterns" => ["^with_current_user"],
        },
      )
    end

    it("does not register an offense in a method matching the pattern") do
      expect_no_offenses(<<~RUBY)
        def with_current_user_context
          CurrentUser.id
        end
      RUBY
    end
  end

  context("with a namespaced ClassName (A::User)") do
    let(:config) do
      RuboCop::Config.new(
        "YiffSpace/CurrentUserOutsideOfRequests" => {
          "ClassName"             => "A::User",
          "IgnoredMethods"        => [],
          "IgnoredMethodPrefixes" => [],
          "IgnoredMethodSuffixes" => [],
          "IgnoredMethodPatterns" => [],
        },
      )
    end

    it("registers an offense for a bare User reference directly inside the A namespace") do
      expect_offense(<<~RUBY)
        module A
          def self.user
            User
            ^^^^ `A::User` should only be used within the request cycle (controllers, views, helpers, decorators)
          end
        end
      RUBY
    end

    it("registers an offense for User.method inside the A namespace") do
      expect_offense(<<~RUBY)
        module A
          def self.user
            User.id
            ^^^^^^^ `A::User` should only be used within the request cycle (controllers, views, helpers, decorators)
          end
        end
      RUBY
    end

    it("registers an offense for a bare User reference in a nested module with no shadowing User") do
      expect_offense(<<~RUBY)
        module A
          module B
            def self.user
              User
              ^^^^ `A::User` should only be used within the request cycle (controllers, views, helpers, decorators)
            end
          end
        end
      RUBY
    end

    it("does not register an offense for User in a module that defines its own User") do
      expect_no_offenses(<<~RUBY)
        module A
          module C
            class User; end

            def self.user
              User
            end
          end
        end
      RUBY
    end

    it("does not register an offense for User outside the A namespace") do
      expect_no_offenses(<<~RUBY)
        def process
          User.id
        end
      RUBY
    end

    it("does not register an offense for User in an unrelated namespace") do
      expect_no_offenses(<<~RUBY)
        module B
          def self.user
            User.id
          end
        end
      RUBY
    end

    it("registers an offense for an absolute ::A::User reference even when a local User is in scope") do
      expect_offense(<<~RUBY)
        module A
          module D
            class User; end

            def self.user
              ::A::User
              ^^^^^^^^^ `A::User` should only be used within the request cycle (controllers, views, helpers, decorators)
            end
          end
        end
      RUBY
    end
  end

  context("with a deeply namespaced ClassName (A::Util::User)") do
    let(:config) do
      RuboCop::Config.new(
        "YiffSpace/CurrentUserOutsideOfRequests" => {
          "ClassName"             => "A::Util::User",
          "IgnoredMethods"        => [],
          "IgnoredMethodPrefixes" => [],
          "IgnoredMethodSuffixes" => [],
          "IgnoredMethodPatterns" => [],
        },
      )
    end

    it("registers an offense for Util::User directly inside A") do
      expect_offense(<<~RUBY)
        module A
          def self.user
            Util::User
            ^^^^^^^^^^ `A::Util::User` should only be used within the request cycle (controllers, views, helpers, decorators)
          end
        end
      RUBY
    end

    it("registers an offense for Util::User inside a nested module within A with no shadowing Util") do
      expect_offense(<<~RUBY)
        module A
          module B
            def self.user
              Util::User
              ^^^^^^^^^^ `A::Util::User` should only be used within the request cycle (controllers, views, helpers, decorators)
            end
          end
        end
      RUBY
    end

    it("does not register an offense for Util::User outside the A namespace") do
      expect_no_offenses(<<~RUBY)
        def process
          Util::User.id
        end
      RUBY
    end
  end

  context("with a custom ClassName") do
    let(:config) do
      RuboCop::Config.new(
        "YiffSpace/CurrentUserOutsideOfRequests" => {
          "ClassName"             => "RequestUser",
          "IgnoredMethods"        => [],
          "IgnoredMethodPrefixes" => [],
          "IgnoredMethodSuffixes" => [],
          "IgnoredMethodPatterns" => [],
        },
      )
    end

    it("registers an offense for the configured class name") do
      expect_offense(<<~RUBY)
        def process
          RequestUser.id
          ^^^^^^^^^^^^^^ `RequestUser` should only be used within the request cycle (controllers, views, helpers, decorators)
        end
      RUBY
    end

    it("does not register an offense for the default CurrentUser name") do
      expect_no_offenses(<<~RUBY)
        def process
          CurrentUser.id
        end
      RUBY
    end

    it("does not register an offense inside the configured class definition") do
      expect_no_offenses(<<~RUBY)
        class RequestUser
          def self.id
            RequestStore[:current_user]&.id
          end
        end
      RUBY
    end
  end
end
