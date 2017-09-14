module AbTestHelper
  def sign_in_via_welcome_test_path(via)
    if rand(2) == 0
      welcome_path(via: build_via(via), ab_test: 'welcome')
    else
      sign_in_path(via: build_via(via), ab_test: 'direct')
    end
  end
end
