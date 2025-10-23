import { useParams } from 'react-router-dom';
import { MessageList } from '../components/Chat/MessageList';
import { MessageForm } from '../components/Chat/MessageForm';

export const ChatPage = () => {
  const { chatId } = useParams<{ chatId: string }>();

  if (!chatId) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-gray-500">No chat selected</div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col h-full">
      <MessageList chatId={chatId} />
      <MessageForm chatId={chatId} />
    </div>
  );
};
