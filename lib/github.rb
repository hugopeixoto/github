require 'net/http'
require 'json'

class GitHub < Struct.new(:access_token)
  def pull_requests(repo)
    paginated(
      "https://api.github.com/repos/#{repo}/pulls",
      Authorization: "token #{access_token}",
      Accept: "application/vnd.github.symmetra-preview+json",
    )
  end

  def merged_pull_requests
    paginated(
      "https://api.github.com/search/issues?q=author:hugopeixoto+is:merged&sort=created&order=asc",
      Authorization: "token #{access_token}",
      Accept: "application/vnd.github.symmetra-preview+json",
    )
  end

  def own_repos
    paginated(
      "https://api.github.com/user/repos",
      Authorization: "token #{access_token}",
      Accept: "application/vnd.github.symmetra-preview+json",
    )
  end

  def user_repos(user)
    paginated(
      "https://api.github.com/users/#{user}/repos",
      Authorization: "token #{access_token}",
      Accept: "application/vnd.github.symmetra-preview+json",
    )
  end

  def repos(organization)
    paginated(
      "https://api.github.com/orgs/#{organization}/repos",
      Authorization: "token #{access_token}",
      Accept: "application/vnd.github.symmetra-preview+json",
    )
  end

  private
  def paginated(starting_url, headers)
    url = starting_url

    result = []

    Enumerator.new do |y|
      while url do
        uri = URI(url)
        req = Net::HTTP::Get.new(uri)
        headers.each { |k, v| req[k] = v }

        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

        url = res["link"]&.yield_self { |links| links.scan(/<(.*?)>; rel="(.*?)"/).map(&:reverse).to_h["next"] }

        JSON.parse(res.body)
          .yield_self { |j| j.include?("items") ? j["items"] : j }
          .each { |item| y.yield(item) }
      end
    end
  end
end


