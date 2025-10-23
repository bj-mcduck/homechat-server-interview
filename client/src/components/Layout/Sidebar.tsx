import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useQuery } from 'urql';
import { USER_CHATS_QUERY } from '../../lib/queries';
import { CreateChatModal } from '../Chat/CreateChatModal';

interface Chat {
  id: string;
  name: string | null;
  private: boolean;
  members: Array<{
    id: string;
    username: string;
    firstName: string;
    lastName: string;
  }>;
}

export const Sidebar = () => {
  const { chatId } = useParams();
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  
  const [{ data, fetching }] = useQuery({ query: USER_CHATS_QUERY });

  if (fetching) {
    return (
      <div className="w-64 bg-gray-50 border-r p-4">
        <div className="animate-pulse">
          <div className="h-4 bg-gray-300 rounded mb-4"></div>
          <div className="h-4 bg-gray-300 rounded mb-2"></div>
          <div className="h-4 bg-gray-300 rounded mb-2"></div>
          <div className="h-4 bg-gray-300 rounded"></div>
        </div>
      </div>
    );
  }

  const chats: Chat[] = data?.userChats || [];
  const groupChats = chats.filter(chat => chat.name);
  const directMessages = chats.filter(chat => !chat.name);

  const getChatDisplayName = (chat: Chat) => {
    if (chat.name) return chat.name;
    
    // For direct messages, show the other participant's name
    const otherMembers = chat.members.filter(member => member.id !== data?.me?.id);
    if (otherMembers.length === 1) {
      return `${otherMembers[0].firstName} ${otherMembers[0].lastName}`;
    }
    
    return `Direct Message (${chat.members.length} people)`;
  };

  return (
    <>
      <div className="w-64 bg-gray-50 border-r flex flex-col">
        {/* Group Chats Section */}
        <div className="p-4 border-b">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-medium text-gray-700">Group Chats</h3>
            <button
              onClick={() => setIsCreateModalOpen(true)}
              className="text-blue-600 hover:text-blue-800 text-sm"
            >
              + Create
            </button>
          </div>
          <div className="space-y-1">
            {groupChats.map((chat) => (
              <Link
                key={chat.id}
                to={`/chat/${chat.id}`}
                className={`block px-3 py-2 rounded-md text-sm ${
                  chatId === chat.id
                    ? 'bg-blue-100 text-blue-700'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                {getChatDisplayName(chat)}
              </Link>
            ))}
          </div>
        </div>

        {/* Direct Messages Section */}
        <div className="p-4 flex-1">
          <h3 className="text-sm font-medium text-gray-700 mb-3">Direct Messages</h3>
          <div className="space-y-1">
            {directMessages.map((chat) => (
              <Link
                key={chat.id}
                to={`/chat/${chat.id}`}
                className={`block px-3 py-2 rounded-md text-sm ${
                  chatId === chat.id
                    ? 'bg-blue-100 text-blue-700'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                {getChatDisplayName(chat)}
              </Link>
            ))}
          </div>
        </div>
      </div>

      <CreateChatModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
      />
    </>
  );
};
