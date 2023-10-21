# frozen_string_literal: true

module Service::Video
  class Bili < Base
    config do
      base_url "https://api.bilibili.com"
    end

    dry do
      headers do
        # use! :ua, :cookie
        string! :cookie
        string! :ua, to: "User-Agent"
        string! :referer, default: "https://www.bilibili.com"
        string! :origin, default: "https://www.bilibili.com"
      end

      define :test do
        string! :bvid
        integer :abc
      end
    end

    api :video_info, "GET /x/web-interface/view" do
      # params { string! :bvid }
      params { use :test }

      response do
        integer! :code, to: :status
      end
    #
    #   response do
    #     json :data do
    #       string! :bvid, to: :uid
    #       string  :author
    #     end
    #   end
    end

    # task :pull do
    #   params { use api: :video_list }
    #
    #   action do
    #     api(:video_list).map { _... }
    #   end
    #
    #   exec do
    #     Video.update_or_create(api(:video_list)).map do |v|
    #       v.subtitles.only_create api(:subtitle, params: { video_id: v.uid })
    #     end
    #   end
    # end
  end
end
