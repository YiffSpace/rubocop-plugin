# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::YiffSpace::BelongsToUser, :config) do
  it("registers an offense for belongs_to(:user) when options are present") do
    expect_offense(<<~RUBY)
      belongs_to(:user, optional: false)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user(:user)` instead of `belongs_to(:user)`
    RUBY

    expect_correction(<<~RUBY)
      belongs_to_user(:user, optional: false)
    RUBY
  end

  it('registers an offense for belongs_to with class_name: "User"') do
    expect_offense(<<~RUBY)
      belongs_to(:creator, class_name: "User")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user(:creator)` instead of `belongs_to(:creator)`
    RUBY

    expect_correction(<<~RUBY)
      belongs_to_user(:creator)
    RUBY
  end

  it("removes class_name while preserving other options") do
    expect_offense(<<~RUBY)
      belongs_to(:creator, class_name: "User", optional: true)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user(:creator)` instead of `belongs_to(:creator)`
    RUBY

    expect_correction(<<~RUBY)
      belongs_to_user(:creator, optional: true)
    RUBY
  end

  it('registers an offense for belongs_to with a string attribute and class_name: "User"') do
    expect_offense(<<~RUBY)
      belongs_to("creator", class_name: "User")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user("creator")` instead of `belongs_to("creator")`
    RUBY

    expect_correction(<<~RUBY)
      belongs_to_user("creator")
    RUBY
  end

  it("does not register an offense for belongs_to(:user) with no options hash") do
    # The cop requires at least one option present to trigger
    expect_no_offenses(<<~RUBY)
      belongs_to(:user)
    RUBY
  end

  it("does not register an offense for belongs_to(:creator) without class_name") do
    expect_no_offenses(<<~RUBY)
      belongs_to(:creator, optional: true)
    RUBY
  end

  it("does not register an offense for belongs_to with a non-User class_name") do
    expect_no_offenses(<<~RUBY)
      belongs_to(:creator, class_name: "Admin")
    RUBY
  end

  it("does not register an offense when already using belongs_to_user") do
    expect_no_offenses(<<~RUBY)
      belongs_to_user(:creator)
    RUBY
  end

  context("with a custom ClassName") do
    let(:config) do
      RuboCop::Config.new("YiffSpace/BelongsToUser" => { "ClassName" => "CurrentUser" })
    end

    it("registers an offense for belongs_to with the inferred attribute name") do
      expect_offense(<<~RUBY)
        belongs_to(:current_user, optional: false)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user(:current_user)` instead of `belongs_to(:current_user)`
      RUBY

      expect_correction(<<~RUBY)
        belongs_to_user(:current_user, optional: false)
      RUBY
    end

    it("registers an offense for belongs_to with the configured class_name") do
      expect_offense(<<~RUBY)
        belongs_to(:creator, class_name: "CurrentUser")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user(:creator)` instead of `belongs_to(:creator)`
      RUBY

      expect_correction(<<~RUBY)
        belongs_to_user(:creator)
      RUBY
    end

    it("does not register an offense for the default :user attribute") do
      expect_no_offenses(<<~RUBY)
        belongs_to(:user, optional: false)
      RUBY
    end

    it('does not register an offense for class_name: "User" when ClassName is CurrentUser') do
      expect_no_offenses(<<~RUBY)
        belongs_to(:creator, class_name: "User")
      RUBY
    end
  end

  context("with a namespaced ClassName") do
    let(:config) do
      RuboCop::Config.new("YiffSpace/BelongsToUser" => { "ClassName" => "Logical::CurrentUser" })
    end

    it("infers the attribute name from the last segment") do
      expect_offense(<<~RUBY)
        belongs_to(:current_user, optional: false)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user(:current_user)` instead of `belongs_to(:current_user)`
      RUBY

      expect_correction(<<~RUBY)
        belongs_to_user(:current_user, optional: false)
      RUBY
    end

    it("matches the full namespaced class_name") do
      expect_offense(<<~RUBY)
        belongs_to(:creator, class_name: "Logical::CurrentUser")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user(:creator)` instead of `belongs_to(:creator)`
      RUBY

      expect_correction(<<~RUBY)
        belongs_to_user(:creator)
      RUBY
    end

    it("does not register an offense for a non-matching class_name") do
      expect_no_offenses(<<~RUBY)
        belongs_to(:creator, class_name: "CurrentUser")
      RUBY
    end
  end

  it('registers an offense for belongs_to with class_name: "User" on the :user attribute') do
    # :user + class_name: "User" triggers the class_name path, not the :user shorthand
    expect_offense(<<~RUBY)
      belongs_to(:user, class_name: "User")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `belongs_to_user(:user)` instead of `belongs_to(:user)`
    RUBY

    expect_correction(<<~RUBY)
      belongs_to_user(:user)
    RUBY
  end
end
