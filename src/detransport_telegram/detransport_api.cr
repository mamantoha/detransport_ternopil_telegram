module DetransportTelegram
  class DetransportAPI
    def initialize
      url = "http://api.detransport.com.ua/"

      @conn = Crest::Resource.new(url)
    end

    def stops
      response = @conn.get("/stops/list")

      Stops.from_json(response.body)
    end

    def show_stop(id)
      response = @conn.post("/vehicles/info/", form: {"stop" => id})

      Vehicles.from_json(response.body)
    end

    class Stops
      include JSON::Serializable

      property stops : Array(Stop)

      def get_by_id(stop_id : String)
        stops.find { |stop| stop.id == stop_id }
      end

      def nearest_to(latitude : Float64, longitude : Float64, count = 5)
        sorted_stops = stops.sort_by do |stop|
          Haversine.distance(stop.lat.to_f, stop.lng.to_f, latitude, longitude)
        end

        sorted_stops.first(count)
      end

      def similar_to(name : String, count = 9)
        similar_stops = stops.sort_by do |stop|
          if name.size >= 4 && stop.name.downcase.includes?(name.downcase)
            1
          else
            JaroWinkler.new.distance(name.downcase, stop.name.sub("вул. ", "").downcase)
          end
        end

        similar_stops.reverse.first(count)
      end
    end

    class Stop
      include JSON::Serializable

      property id : String

      property name : String

      property lat : String

      property lng : String

      property vehicles : Array(StopVehicle)

      def full_name
        "🚏 #{name}"
      end
    end

    class StopVehicle
      include JSON::Serializable

      @[JSON::Field(key: "type")]
      property vehicle_type : String

      property name : String

      def icon
        case vehicle_type
        when "1"
          "🚌"
        when "2"
          "🚎"
        else
          "🚌"
        end
      end
    end

    class Vehicles
      include JSON::Serializable

      property vehicles : Array(Vehicle)
    end

    class Vehicle
      include JSON::Serializable

      @[JSON::Field(key: "type")]
      property vehicle_type : String

      property name : String

      property bort_number : String

      property lat : String

      property lng : String

      property angle : Int32

      property time : Int32

      property ramp : String

      property distance : Int32

      property comment : String

      property timenext : Int32?

      property distancenext : Int32?

      property bort_numbernext : String?

      def full_name
        human_time = HumanizeTime.distance_of_time_in_words(Time.local, Time.local + time.seconds, include_seconds: true)
        "#{transport_icon} *#{name}* (_#{comment}_) —  #{human_time}"
      end

      def transport_icon
        case vehicle_type
        when "1"
          "🚌"
        when "2"
          "🚎"
        else
          "🚌"
        end
      end
    end
  end
end
