module MusiciansHelper
  def musician_status_badge(musician)
    case musician.status
    when "looking_for_band"
      content_tag(:span, "Looking for Band", class: "badge bg-warning text-dark")
    when "set_musician"
      content_tag(:span, "Set Musician", class: "badge bg-success")
    else
      content_tag(:span, "Unknown", class: "badge bg-secondary")
    end
  end
end
