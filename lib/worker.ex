defmodule Metex.Worker do
    
    def loop do
        receive do
            {sender_pid, location} ->
                send(sender_pid, {:ok, temperature_of(location)})
            msg -> 
                IO.puts "don't know how to process this message - #{msg}"
        end
        loop()
    end

    defp temperature_of(location) do
        result = location |> url_for |> HTTPoison.get |> parse_response
        case result do
            {:ok, temp} ->
                "#{location}: #{temp}C"
            {:error, reason} ->
                "#{location} error: #{reason}"                
            :error ->
                "some error"
        end
    end

    defp url_for(location) do
        location = URI.encode(location)
        "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey()}"
    end

    defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
        body |> JSON.decode! |> compute_temperature
    end

    defp parse_response({:ok, %HTTPoison.Response{status_code: 404}}) do
        {:error, "not found"}
    end

    defp parse_response(_) do
        :error
    end

    defp compute_temperature(json) do
        try do
            temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
            {:ok, temp}
        rescue
            _ -> :error
        end
    end

    defp apikey do
        "5a513c30007f4555987383dc50d544c4"
    end

end
