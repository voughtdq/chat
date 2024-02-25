defmodule MyMutex do
    @mutex :free
  
    def lock(:free) do
      {:ok, :locked}
    end
  
    def lock(:locked) do
      {:error, :already_locked}
    end
  
    def unlock(:locked) do
      {:ok, :free}
    end
  
    def unlock(:free) do
      {:error, :not_locked}
    end
  end
  
  defmodule Chat do
  
    defstruct users: [], messages: [], mutex: :free
  
    def start_link() do
      {:ok, pid} = Task.start_link(fn -> action(%__MODULE__{}) end)
    end
  
    defp action(chat) do
      receive do
      {:join, user} ->
        chat = new_user(chat, user)
        action(chat)
      #{:post, user} ->
      #  chat = post_message(chat, user)
      #  action(chat)
      {:disconnect, user} ->
        chat = disconnect_user(chat, user)
        action(chat)
      {:users_chat} ->
        post_all_users(chat)
        action(chat)
      end
    end
  
    defp post_all_users(chat) do
      case chat.users do
        [] -> IO.puts("No users online.")
        users ->
          IO.puts("Users: ")
          Enum.each(users, fn user -> 
            IO.puts(" - #{user}") 
          end)
      end
    end
  
    defp post_message_to_all(chat, message) do
      Enum.each(chat.users, fn user ->
        IO.puts("Message from server: #{message} (Sent to: #{user})")
      end)
    end
  
    defp new_user(chat ,user) do
      {:ok, mutex} = MyMutex.lock(chat.mutex)
      updated_chat = %{chat | users: chat.users ++ [user], mutex: mutex }
      IO.puts("Entering the chat: #{user}")
      {:ok, mutex} = MyMutex.unlock(mutex)
      updated_chat = %{updated_chat | mutex: mutex}
      post_message_to_all(updated_chat, "#{user} has joined the chat.")
      updated_chat
    end
  
    defp disconnect_user(chat, user) do
      {:ok, mutex} = MyMutex.lock(chat.mutex)
      chat = %{chat | users: List.delete(chat.users, user),
              mutex: mutex}
      IO.puts("The user #{user} has leaved the chat")
      {:ok, mutex} = MyMutex.unlock(mutex)
      %{chat | mutex: mutex}
    end
  end
  