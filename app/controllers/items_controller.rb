class ItemsController < ApplicationController
  before_action :move_to_index, except: [:index, :show, :search]
  before_action :category_parent_array, only: [:new, :create, :edit, :update]
  before_action :set_item, only: [:show, :edit, :update, :destroy]
  
  def index
    @items = Item.includes(:item_images).limit(3).order('created_at DESC')
    # レディース新着アイテムとメンズ新着アイテム
    @ladies_items = Item.where(category: 159..346).includes(:item_images).limit(3).order("created_at DESC")
    @mens_items = Item.where(category: 347..476).includes(:item_images).limit(3).order("created_at DESC")
  end
  
  def new
    @item = Item.new
    @item.item_images.new
  end
  
  # 以下全て、formatはjsonのみ
  # 親カテゴリが選択された後に動くアクション
  def get_category_children
    # 選択された親カテゴリに紐づく子カテゴリの配列を取得する
    @category_children = Category.find("#{params[:parent_id]}").children
  end
  
  # 子カテゴリが選択された後に動くアクション
  def get_category_grandchildren
    # 選択された子カテゴリに紐づく孫カテゴリの配列を取得する
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end
  
  # 孫カテゴリが選択された後に動くアクション（サイズ）
  def get_size
    selected_grandchild = Category.find("#{params[:grandchild_id]}") 
    if related_size_parent = selected_grandchild.sizes[0] 
      @sizes = related_size_parent.children
    else
      selected_child = Category.find("#{params[:grandchild_id]}").parent
      if related_size_parent = selected_child.sizes[0]
        @sizes = related_size_parent.children
      end
    end
  end
  
  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to root_path
      flash[:notice] = "商品を出品しました"
    else
      render :new
    end
  end

  def show
    @comment = Comment.new
    @comments = @item.comments.includes(:user)
    @category_grandchild = @item.category
    @category_child = @category_grandchild.parent
    @category_parent = @category_child.parent
  end

  def edit
    @images = ItemImage.where(item_id: params[:id])
  end


  def update
    if @item.update(item_params)
      redirect_to root_path
      flash[:notice] = "商品を編集しました"
    else
      redirect_back(fallback_location: root_path)
      flash[:alert] = "商品の編集に失敗しました"
    end
  end
  
  def search
    @search_items = Item.search(params[:key])
  end

  def destroy
    if @item.destroy
      redirect_to root_path
      flash[:notice] = "商品を削除しました"
    else
      redirect_back(fallback_location: root_path)
      flash[:alert] = "商品の削除に失敗しました"
    end
  end


  def move_to_index
    unless user_signed_in?
      redirect_to action: :index
    end
  end

  private

  def item_params
    params.require(:item).permit(:name, :price, :explanation, :category_id, :size_id, :item_condition_id, :prefecture_id, :delivery_fee_id, :preparation_day_id, item_images_attributes: [:src, :_destroy, :id]).merge(seller_id: current_user.id)
  end

  def category_parent_array
    @category_parent_array = Category.where(ancestry: nil)
  end

  def set_item
    @item = Item.find(params[:id])
  end

end