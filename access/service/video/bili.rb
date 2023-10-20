# frozen_string_literal: true

module Service::Video
  class Bili < Base
    config do
      base_url "https://api.bilibili.com"
    end

    api :video_info, "GET /x/web-interface/view" do
      params { string! :bvid }

      response do
        string :code, to: :status
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
    #   action do
    #     Video.update_or_create(api(:video_list)).map do |v|
    #       v.subtitles.only_create api(:subtitle, params: { video_id: v.uid })
    #     end
    #   end
    # end
  end
end
